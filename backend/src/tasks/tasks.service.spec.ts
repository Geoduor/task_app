import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';
import { TasksService } from './tasks.service';
import { Task } from './schemas/task.schema';

describe('TasksService', () => {
  let service: TasksService;

  const mockDoc = (overrides: Partial<any> = {}) => ({
    _id: new Types.ObjectId(),
    title: 'Sample task',
    completed: false,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  });

  const taskModelMock = {
    create: jest.fn(),
    find: jest.fn(),
    findByIdAndUpdate: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TasksService,
        { provide: getModelToken(Task.name), useValue: taskModelMock },
      ],
    }).compile();

    service = module.get<TasksService>(TasksService);
  });

  it('creates a task and trims the title', async () => {
    const doc = mockDoc({ title: 'Buy milk' });
    taskModelMock.create.mockResolvedValue(doc);

    const result = await service.create({ title: '  Buy milk  ' } as any);

    expect(taskModelMock.create).toHaveBeenCalledWith({
      title: 'Buy milk',
      completed: false,
    });
    expect(result.title).toBe('Buy milk');
    expect(result.completed).toBe(false);
  });

  it('rejects an invalid id with 400 before touching the DB', async () => {
    await expect(service.complete('not-a-valid-id')).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(taskModelMock.findByIdAndUpdate).not.toHaveBeenCalled();
  });

  it('throws 404 when a valid id does not exist', async () => {
    taskModelMock.findByIdAndUpdate.mockReturnValue({
      exec: jest.fn().mockResolvedValue(null),
    });

    await expect(
      service.complete(new Types.ObjectId().toString()),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('marks a task as completed', async () => {
    const id = new Types.ObjectId();
    const doc = mockDoc({ _id: id, completed: true });
    taskModelMock.findByIdAndUpdate.mockReturnValue({
      exec: jest.fn().mockResolvedValue(doc),
    });

    const result = await service.complete(id.toString());

    expect(result.completed).toBe(true);
    expect(result.id).toBe(id.toString());
  });
});
